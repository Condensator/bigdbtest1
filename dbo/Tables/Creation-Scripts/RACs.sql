SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RACs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Number] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Status] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[ApplicationType] [nvarchar](17) COLLATE Latin1_General_CI_AS NOT NULL,
	[Corporate] [bit] NOT NULL,
	[UnderwriterInstructions] [nvarchar](750) COLLATE Latin1_General_CI_AS NULL,
	[Replacement] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RACProgramId] [bigint] NOT NULL,
	[OriginalRACId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[BusinessUnitId] [bigint] NOT NULL,
	[ProgramId] [bigint] NULL,
	[IsAllVendors] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[RACs]  WITH CHECK ADD  CONSTRAINT [ERAC_BusinessUnit] FOREIGN KEY([BusinessUnitId])
REFERENCES [dbo].[BusinessUnits] ([Id])
GO
ALTER TABLE [dbo].[RACs] CHECK CONSTRAINT [ERAC_BusinessUnit]
GO
ALTER TABLE [dbo].[RACs]  WITH CHECK ADD  CONSTRAINT [ERAC_OriginalRAC] FOREIGN KEY([OriginalRACId])
REFERENCES [dbo].[RACs] ([Id])
GO
ALTER TABLE [dbo].[RACs] CHECK CONSTRAINT [ERAC_OriginalRAC]
GO
ALTER TABLE [dbo].[RACs]  WITH CHECK ADD  CONSTRAINT [ERAC_Program] FOREIGN KEY([ProgramId])
REFERENCES [dbo].[Programs] ([Id])
GO
ALTER TABLE [dbo].[RACs] CHECK CONSTRAINT [ERAC_Program]
GO
ALTER TABLE [dbo].[RACs]  WITH CHECK ADD  CONSTRAINT [ERAC_RACProgram] FOREIGN KEY([RACProgramId])
REFERENCES [dbo].[RACPrograms] ([Id])
GO
ALTER TABLE [dbo].[RACs] CHECK CONSTRAINT [ERAC_RACProgram]
GO
