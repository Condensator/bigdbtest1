SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RVILineofBusinesses](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LineofBusinessId] [bigint] NOT NULL,
	[RVIParameterId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[RVILineofBusinesses]  WITH CHECK ADD  CONSTRAINT [ERVILineofBusiness_LineofBusiness] FOREIGN KEY([LineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[RVILineofBusinesses] CHECK CONSTRAINT [ERVILineofBusiness_LineofBusiness]
GO
ALTER TABLE [dbo].[RVILineofBusinesses]  WITH CHECK ADD  CONSTRAINT [ERVIParameter_RVILineofBusinesses] FOREIGN KEY([RVIParameterId])
REFERENCES [dbo].[RVIParameters] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[RVILineofBusinesses] CHECK CONSTRAINT [ERVIParameter_RVILineofBusinesses]
GO
