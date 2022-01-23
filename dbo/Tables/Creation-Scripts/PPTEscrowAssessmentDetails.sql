SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PPTEscrowAssessmentDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[TransactionType] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[DRAmount_Amount] [decimal](16, 2) NULL,
	[DRAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[CRAmount_Amount] [decimal](16, 2) NULL,
	[CRAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[DRAccount] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[CRAccount] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[DRDescription] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[CRDescription] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[PostDate] [date] NULL,
	[EscrowEndBalance_Amount] [decimal](16, 2) NULL,
	[EscrowEndBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[GLCreatedTime] [datetimeoffset](7) NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PPTEscrowAssessmentId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PPTEscrowAssessmentDetails]  WITH CHECK ADD  CONSTRAINT [EPPTEscrowAssessment_PPTEscrowAssessmentDetails] FOREIGN KEY([PPTEscrowAssessmentId])
REFERENCES [dbo].[PPTEscrowAssessments] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PPTEscrowAssessmentDetails] CHECK CONSTRAINT [EPPTEscrowAssessment_PPTEscrowAssessmentDetails]
GO
